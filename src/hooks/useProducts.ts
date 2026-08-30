// useProducts.ts - Hook React pour boutique/social feed
// Connecte le frontend aux vraies tables Supabase
// MVP Phase 1: Beauty Social Commerce

import { useState, useEffect } from 'react';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

export interface Product {
  id: number;
  brand_id: number;
  name: string;
  slug: string;
  category: string;
  subcategory?: string;
  description?: string;
  target_audience: 'men' | 'women' | 'unisex';
  skin_types?: any[];
  olfactory_families?: any[];
  ingredients?: string;
  instructions?: string;
  precautions?: string;
  volume_unit: string;
  price_xof: number;
  original_price_xof?: number;
  discount_percentage: number;
  is_featured: boolean;
  is_active: boolean;
  created_at: string;
  updated_at: string;
  quantity_available: number;
}

export interface ProductError {
  code: string;
  message: string;
  details?: any;
}

export function useProducts() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [filteredProducts, setFilteredProducts] = useState<Product[]>([]);

  // Charger tous les produits actifs
  useEffect(() => {
    loadProducts();
  }, []);

  const loadProducts = async () => {
    try {
      setLoading(true);
      
      // Lecture des produits actifs via Supabase (RLS: public voit is_active=true)
      const { data, error } = await supabase
        .from('products')
        .select('*')
        .eq('is_active', true)
        .order('price_xof', { ascending: false });

      if (error) throw error;
      
      if (data && data.length > 0) {
        setProducts(data);
        setFilteredProducts(data);
      }
    } catch (err) {
      setError(err as Error);
    } finally {
      setLoading(false);
    }
  };

  const filterByCategory = (category: string) => {
    setFilteredProducts(products.filter(p => p.category === category));
  };

  const filterByBrand = (brandSlug: string) => {
    // Récupérer brand_id par slug via brands table
    supabase
      .from('brands')
      .select('id, slug')
      .eq('slug', brandSlug)
      .single()
      .then(({ data: brand }) => {
        if (brand && brand.id) {
          setFilteredProducts(products.filter(p => p.brand_id === brand.id));
        } else {
          setFilteredProducts([]);
        }
      });
  };

  const getProductBySlug = async (slug: string): Promise<Product | null> => {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .eq('slug', slug)
      .eq('is_active', true)
      .single();

    if (error || !data) return null;
    return data as Product;
  };

  const addToCart = async (product: Product, quantity: number = 1): Promise<void> => {
    // Vérifier stock
    if (product.quantity_available < quantity) {
      throw new Error(`Stock insuffisant: ${product.quantity_available} disponibles`);
    }

    // Créer ou mettre à jour care_cart_item
    try {
      const { data: cartItem, error } = await supabase
        .from('care_cart_items')
        .select('*')
        .eq('profile_id', 'current-user-id-placeholder') // TODO: remplacer par auth.uid()
        .eq('product_id', product.id)
        .single();

      if (error && error.code === 'PGRST116') {
        // Item n'existe pas, créer
        const { error: insertError } = await supabase
          .from('care_cart_items')
          .insert({
            profile_id: 'current-user-id-placeholder', // TODO: auth.uid()
            product_id: product.id,
            quantity: quantity,
            status: 'recommended' as const,
          });

        if (insertError) throw insertError;
      } else if (error) {
        throw error;
      }
    } catch (err) {
      console.error('Failed to add to cart:', err);
      throw err;
    }
  };

  return {
    products,
    filteredProducts,
    loading,
    error,
    filterByCategory,
    filterByBrand,
    getProductBySlug,
    addToCart,
    refresh: loadProducts,
  };
}

export default useProducts;